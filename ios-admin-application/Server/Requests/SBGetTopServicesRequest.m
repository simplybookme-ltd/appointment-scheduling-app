//
//  SBGetTopServicesRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 01.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetTopServicesRequest.h"
#import "SBRequestOperation_Private.h"

@interface SBGetTopServicesResultProcessor : SBResultProcessor
@end

@implementation SBGetTopServicesRequest

- (NSString *)method
{
    return @"getTopServices";
}

- (SBResultProcessor *)resultProcessor
{
    return [SBGetTopServicesResultProcessor new];
}

@end

@implementation SBGetTopServicesResultProcessor

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
