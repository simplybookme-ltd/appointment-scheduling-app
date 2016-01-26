//
//  SBPluginApproveGetPendingBookingsRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 16.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBPluginApproveGetPendingBookingsRequest.h"
#import "SBRequestOperation_Private.h"
#import "NSDateFormatter+ServerParser.h"

@interface SBPluginApproveGetPendingBookingsResultProcessor : SBResultProcessor
@end

@implementation SBPluginApproveGetPendingBookingsRequest

- (NSString *)method
{
    return @"pluginApproveGetPendingBookings";
}

- (SBResultProcessor *)resultProcessor
{
    return [[SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSArray class]]
            addResultProcessorToChain:[SBPluginApproveGetPendingBookingsResultProcessor new]];
}

@end

@implementation SBPluginApproveGetPendingBookingsResultProcessor

- (BOOL)process:(NSArray <NSDictionary *> *)result
{
    NSMutableArray *list = [NSMutableArray array];
    [result enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *booking = [obj mutableCopy];
        booking[@"start_date"] = [[NSDateFormatter sb_serverDateTimeFormatter] dateFromString:booking[@"start_date"]];
        booking[@"end_date"] = [[NSDateFormatter sb_serverDateTimeFormatter] dateFromString:booking[@"end_date"]];
        [list addObject:booking];
    }];
    self.result = list;
    return [self chainResult:self.result success:YES];
}

@end