//
//  CalendarWeekViewController.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 04.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CalendarViewController.h"
#import "CalendarBookingsViewController.h"

@class SBGetBookingsFilter;

@interface CalendarWeekViewController : CalendarBookingsViewController <CalendarViewContainerChildController>

@property (nonatomic, strong) SBGetBookingsFilter *filter;

@end
