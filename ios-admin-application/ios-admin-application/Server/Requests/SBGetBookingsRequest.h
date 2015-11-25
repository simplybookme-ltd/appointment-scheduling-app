//
//  SBGetBookingsRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"
#import "SBGetBookingsFilter.h"

@interface SBGetBookingsRequest : SBRequestOperation

@property (nonatomic, copy) SBGetBookingsFilter *filter;

@end
