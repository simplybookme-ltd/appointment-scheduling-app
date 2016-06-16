//
//  CalendarBookingsViewController.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 25.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSManagedObjectContext.h"
#import "SBBooking.h"
#import "SBPerformer.h"

@interface CalendarBookingsViewController : UIViewController

@property (nonatomic, strong) LSManagedObjectContext *managedObjectContext;

- (void)processBookings:(NSArray <SBBooking *> *)bookings;
- (void)processPerformers:(SBPerformersCollection *)performers;

@end
