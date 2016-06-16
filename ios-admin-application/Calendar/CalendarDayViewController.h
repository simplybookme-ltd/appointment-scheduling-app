//
//  CalendarDayViewController.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 03.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CalendarBookingsViewController.h"
#import "CalendarViewController.h"

@class SBGetBookingsFilter;

@interface CalendarDayViewController : CalendarBookingsViewController <CalendarViewContainerChildController>

@property (nonatomic, strong) SBGetBookingsFilter *filter;

@end
