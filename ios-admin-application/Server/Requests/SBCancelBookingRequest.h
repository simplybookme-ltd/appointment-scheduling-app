//
//  SBCancelBookingRequest.h
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 11.08.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "SBRequestOperation.h"

@interface SBCancelBookingRequest : SBRequestOperation

@property (nonatomic, copy) NSString *bookingID;

@end
