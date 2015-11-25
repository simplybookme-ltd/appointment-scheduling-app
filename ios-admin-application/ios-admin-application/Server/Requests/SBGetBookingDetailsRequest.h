//
//  SBGetBookingDetailsRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 25.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

@interface SBGetBookingDetailsRequest : SBRequestOperation

@property (nonatomic, copy) NSString *bookingID;

@end
