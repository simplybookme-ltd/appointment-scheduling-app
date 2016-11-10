//
//  SBGetWorkDaysTimesRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 22.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kSBGetWorkDaysTimesRequest_DefaultType;
extern NSString * const kSBGetWorkDaysTimesRequest_PerformerType;
extern NSString * const kSBGetWorkDaysTimesRequest_ServiceType;

@interface SBGetWorkDaysTimesRequest : SBRequestOperation

@property (nonatomic, copy) NSDate *startDate;
@property (nonatomic, copy) NSDate *endDate;
@property (nonatomic, copy) NSString *type;

@end

NS_ASSUME_NONNULL_END
