//
//  CalendarWeekViewController.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 04.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CalendarViewController.h"

@class SBGetBookingsFilter;

@interface CalendarWeekViewController : UIViewController <CalendarViewContainerChildController>

@property (nonatomic, strong) SBGetBookingsFilter *filter;
@property (nonatomic, copy) NSString *dataLoaderType;

@end
