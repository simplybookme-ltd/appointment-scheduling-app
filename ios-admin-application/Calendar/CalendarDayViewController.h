//
//  CalendarDayViewController.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 03.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CalendarViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class SBGetBookingsFilter;

@interface CalendarDayViewController : UIViewController <CalendarViewContainerChildController>

@property (nonatomic, strong) SBGetBookingsFilter *filter;
@property (nonatomic, copy) NSString *dataLoaderType;

@end

NS_ASSUME_NONNULL_END
