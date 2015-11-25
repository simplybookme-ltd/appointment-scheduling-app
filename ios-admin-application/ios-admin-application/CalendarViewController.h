//
//  CalendarViewController.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 19.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwipeContainerViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class SBGetBookingsFilter;
@class CalendarViewController;

@protocol CalendarViewContainerChildController

@property (readonly) SBGetBookingsFilter *getBookingsFilter;

- (void)showAddBookingForm;
- (void)filterDidChange:(SBGetBookingsFilter *)filter requiresReset:(BOOL)reset;
- (void)willEmbedToCalendarViewContainer:(UIViewController *)viewContainer;
- (void)willRemoveFromCalendarViewContainer:(UIViewController *)viewContainer;
- (void)didEmbedToCalendarViewContainer:(UIViewController *)viewContainer;
- (void)didRemoveFromCalendarViewContainer:(UIViewController *)viewContainer;

@end

@interface CalendarViewController : UIViewController <SwipeContainerViewControllerDelegate>

@end

NS_ASSUME_NONNULL_END
