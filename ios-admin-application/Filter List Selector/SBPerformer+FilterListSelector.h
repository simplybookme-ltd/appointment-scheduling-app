//
//  SBPerformer+FilterListSelector.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 24.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBPerformer.h"
#import "FilterListSelectorViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SBPerformer (FilterListSelector) <FilterListSelectorItemProtocol>

@property (nonatomic, strong, readonly) NSString *itemID;
@property (nonatomic, strong, readonly, nullable) NSString *title;
@property (nonatomic, strong, readonly) NSString *subtitle;
@property (nonatomic, strong, readonly, nullable) UIColor *colorObject;

@end

NS_ASSUME_NONNULL_END