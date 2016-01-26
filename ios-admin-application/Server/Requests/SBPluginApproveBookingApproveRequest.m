//
//  SBPluginApproveBookingApproveRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 16.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBPluginApproveBookingApproveRequest.h"
#import "SBRequestOperation_Private.h"

@interface SBPluginApproveBookingApproveResultProcessor : SBResultProcessor

@end

@implementation SBPluginApproveBookingApproveRequest

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.bookingID = self.bookingID;
    return copy;
}

- (NSString *)method
{
    return @"pluginApproveBookingApprove";
}

- (NSArray *)params
{
    NSAssert(self.bookingID != nil, @"required parametr 'bookingID' can't be nil");
    return @[self.bookingID];
}

- (SBResultProcessor *)resultProcessor
{
    return [SBPluginApproveBookingApproveResultProcessor new];
}

- (SBCachePolicy)cachePolicy
{
    return SBNoCachePolicy;
}

@end

@implementation SBPluginApproveBookingApproveResultProcessor

- (BOOL)process:(id)result
{
    /**
     * API method `pluginApproveBookingApprove` can return boolean in case if plugin disabled.
     */
    if ([result isKindOfClass:[NSNumber class]] || ([result isKindOfClass:[NSString class]] && [result isEqualToString:@"0"])) {
        self.result = @[];
        return [self chainResult:self.result success:YES];
    }
    SBResultProcessor *classCheck = [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSArray class]];
    BOOL check = [classCheck process:result];
    self.result = classCheck.result;
    self.error = classCheck.error;
    return [self chainResult:self.result success:check];
}

@end