//
//  SBPluginApproveGetPendingBookingsCountRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 16.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBPluginApproveGetPendingBookingsCountRequest.h"
#import "SBRequestOperation_Private.h"

@implementation SBPluginApproveGetPendingBookingsCountRequest

- (NSString *)method
{
    return @"pluginApproveGetPendingBookingsCount";
}

- (SBResultProcessor *)resultProcessor
{
    return [SBNumberProcessor new];
}

@end
