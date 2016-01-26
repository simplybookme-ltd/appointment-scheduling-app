//
//  BookingsListViewController.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 30.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SBBooking.h"

@class SBBookingStatusesCollection;

@interface BookingsListViewController : UIViewController

@property (nonatomic, strong, nonnull) NSArray <SBBookingObject *> *bookings;
@property (nonatomic, strong, nullable) SBBookingStatusesCollection * statuses;
@property (nonatomic) NSTimeInterval timeframeStep;

@end
