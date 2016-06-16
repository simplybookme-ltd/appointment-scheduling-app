//
//  SBGetGoogleCalendarBusyTimeRequests.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 15.02.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

@interface SBGetGoogleCalendarBusyTimeRequest : SBRequestOperation

@property (nonatomic, copy) NSDate *startDate;
@property (nonatomic, copy) NSDate *endDate;
@property (nonatomic, copy) NSString *unitID;

@end
