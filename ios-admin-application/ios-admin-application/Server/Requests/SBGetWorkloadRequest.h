//
//  SBGetWorkloadRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 23.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

@interface SBGetWorkloadRequest : SBRequestOperation

@property (nonatomic, copy) NSDate *startDate;
@property (nonatomic, copy) NSDate *endDate;
@property (nonatomic, copy) NSString *performerID;

@end
