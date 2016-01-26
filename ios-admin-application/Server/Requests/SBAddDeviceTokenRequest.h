//
//  SBAddDeviceTokenRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 03.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

@interface SBAddDeviceTokenRequest : SBRequestOperation

@property (nonatomic, copy) NSString *deviceToken;

@end
