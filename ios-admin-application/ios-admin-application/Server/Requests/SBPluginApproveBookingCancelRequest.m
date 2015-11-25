//
//  SBPluginApproveBookingCancelRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 16.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBPluginApproveBookingCancelRequest.h"
#import "SBRequestOperation_Private.h"

@implementation SBPluginApproveBookingCancelRequest

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.bookingID = self.bookingID;
    return copy;
}

- (NSString *)method
{
    return @"pluginApproveBookingCancel";
}

- (NSArray *)params
{
    NSAssert(self.bookingID != nil, @"required parametr 'bookingID' can't be nil");
    return @[self.bookingID];
}

- (SBCachePolicy)cachePolicy
{
    return SBNoCachePolicy;
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSNumber class]];
}

@end
