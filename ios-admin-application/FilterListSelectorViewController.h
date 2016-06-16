//
//  FilterListSelectorViewController.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 27.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBCollection.h"

NS_ASSUME_NONNULL_BEGIN

@class FilterListSelectorViewController;

@protocol FilterListSelectorItemProtocol <SBCollectionEntryProtocol, SBCollectionSortingProtocol>

@property (nonatomic, strong, readonly) NSString *itemID;
@property (nonatomic, strong, readonly, nullable) NSString *title;
@property (nonatomic, strong, readonly) NSString *subtitle;
@property (nonatomic, strong, readonly, nullable) UIColor *colorObject;

@end

@protocol FilterListSelectorDelegate <NSObject>

- (nullable NSString *)titleForAnyItemInFilterListSelector:(FilterListSelectorViewController *)selector;
- (BOOL)isAnyItemEnabledForFilterListSelector:(FilterListSelectorViewController *)selector;
- (void)filterListSelector:(FilterListSelectorViewController *)selector didSelectItem:(nullable NSObject<FilterListSelectorItemProtocol> *)item;
- (void)filterListSelectorWillDisappear:(FilterListSelectorViewController *)selector;

@end

@interface FilterListSelectorViewController : UITableViewController

@property (nonatomic, weak, nullable) NSObject <FilterListSelectorDelegate> *filterListSelectorDelegate;
@property (nonatomic, strong) SBCollection <NSObject<FilterListSelectorItemProtocol> *> *collection;

@end

NS_ASSUME_NONNULL_END
