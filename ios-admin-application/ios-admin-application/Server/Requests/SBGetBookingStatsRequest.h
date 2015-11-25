//
//  SBGetBookingStatsRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 29.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

@interface SBGetBookingStatsRequest : SBRequestOperation

@property (nonatomic, copy) NSString *timePeriod;

@end
