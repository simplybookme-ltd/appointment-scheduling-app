//
//  SBGetUnitList.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 29.07.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "SBGetUnitListRequest.h"
#import "SBRequestOperation_Private.h"
#import "SBPerformer.h"

@interface SBGetUnitListResultProcessor : SBResultProcessor

@end

@implementation SBGetUnitListRequest

- (NSString *)method
{
    return @"getUnitList";
}

- (SBResultProcessor *)resultProcessor
{
    return [[SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSDictionary class]]
            addResultProcessorToChain:[SBGetUnitListResultProcessor new]];
}

@end

@implementation SBGetUnitListResultProcessor

- (BOOL)process:(id)result
{
    self.result = [[SBPerformersCollection alloc] initWithDictionary:result builder:[SBPerformerEntryBuilder new]];
    return [super process:self.result];
}

@end
