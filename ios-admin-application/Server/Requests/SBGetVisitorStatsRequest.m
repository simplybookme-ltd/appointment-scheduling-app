//
//  SBGetVisitorStatsRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 23.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetVisitorStatsRequest.h"
#import "SBRequestOperation_Private.h"

@implementation SBGetVisitorStatsRequest

- (NSString *)method
{
    return @"getVisitorStats";
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSDictionary class]];
}

@end