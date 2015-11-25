//
//  SBNewBookingPlaceholder.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 16.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBBooking.h"

@interface SBNewBookingPlaceholder : NSObject <SBBookingProtocol>

@property (nonatomic, strong) NSString *bookingID;
@property (nonatomic, strong) NSString *performerID;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSNumber *isConfirmed;
@property (nonatomic, strong) NSString *statusID;

@end
