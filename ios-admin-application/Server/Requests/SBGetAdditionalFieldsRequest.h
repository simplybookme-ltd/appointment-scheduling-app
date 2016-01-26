//
//  SBGetAdditionalFieldsRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 02.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

@interface SBGetAdditionalFieldsRequest : SBRequestOperation

@property (nonatomic, copy) NSString *eventID;

@end
