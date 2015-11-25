//
//  SBGetUnitWorkdayInfoRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 21.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

@interface SBGetUnitWorkdayInfoRequest : SBRequestOperation

@property (nonatomic, copy) NSDate *startDate;
@property (nonatomic, copy) NSDate *endDate;

@end
