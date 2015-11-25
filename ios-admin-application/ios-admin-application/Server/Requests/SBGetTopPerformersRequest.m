//
//  SBGetTopPerformersRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 23.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetTopPerformersRequest.h"
#import "SBRequestOperation_Private.h"

@interface SBGetTopPerformersResultProcessor : SBResultProcessor
@end

@implementation SBGetTopPerformersRequest

- (NSString *)method
{
    return @"getTopPerformers";
}

- (SBResultProcessor *)resultProcessor
{
    return [SBGetTopPerformersResultProcessor new];
}

@end

@implementation SBGetTopPerformersResultProcessor

- (BOOL)process:(id)result
{
    SBClassCheckProcessor *classCheckProcessor = [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSArray class]];
    if (![classCheckProcessor process:result]) {
        self.error = classCheckProcessor.error;
        return NO;
    }
    SBSafeDictionaryProcessor *safeDictionaryProcessor = [SBSafeDictionaryProcessor safeDictionaryProcessor];
    NSMutableArray *res = [NSMutableArray array];
    [(NSArray *)result enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([safeDictionaryProcessor process:obj]) {
            [res addObject:safeDictionaryProcessor.result];
        }
    }];
    self.result = res;
    return YES;
}

@end
