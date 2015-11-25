//
//  FilterViewController.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 26.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBGetBookingsFilter.h"

@class FilterViewController;

@protocol FilterViewControllerDelegate <NSObject>

- (void)filterController:(FilterViewController *)filterController didSetNewFilter:(SBGetBookingsFilter *)filter reset:(BOOL)reset;
- (void)filterControllerDidCancel:(FilterViewController *)filterController;

@end

@interface FilterViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) SBGetBookingsFilter *initialFilter;
@property (nonatomic, weak) NSObject<FilterViewControllerDelegate> *delegate;

@end
