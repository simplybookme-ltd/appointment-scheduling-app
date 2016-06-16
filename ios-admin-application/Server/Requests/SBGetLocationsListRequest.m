//
//  SBGetCategoriesListRequest.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 22.07.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "SBGetLocationsListRequest.h"
#import "SBRequestOperation_Private.h"

@interface SBGetLocationsListResultProcessor : SBResultProcessor

@end

@implementation SBGetLocationsListRequest

- (NSString *)method
{
    return @"getLocationsList";
}

- (SBResultProcessor *)resultProcessor
{
    return [[SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSDictionary class]]
            addResultProcessorToChain:[SBGetLocationsListResultProcessor new]];
}

@end

@implementation SBGetLocationsListResultProcessor

- (BOOL)process:(id)result
{
    // TODO: check if possible to use SBCollection
    SBClassCheckProcessor *classCheck = [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSDictionary class]];
    NSMutableArray *list = [NSMutableArray array];
    for (NSDictionary *categoryData in [result allValues]) {
        if (![classCheck process:categoryData]) {
            self.error = classCheck.error;
            return [self chainResult:result success:NO];
        }
        NSMutableDictionary *data = [categoryData mutableCopy];
        NSArray *keys = [data allKeys];
        for (NSString *key in keys) {
            if ([[data objectForKey:key] isEqual:[NSNull null]]) {
                [data removeObjectForKey:key];
            }
        }
        [list addObject:[data copy]];
    }
    self.result = [list sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        return [obj1[@"position"] compare:obj2[@"position"]];
    }];
    return [self chainResult:self.result success:YES];
}

@end