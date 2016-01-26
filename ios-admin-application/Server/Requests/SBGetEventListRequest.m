//
//  SBGetEventListRequest.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 24.07.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "SBGetEventListRequest.h"
#import "SBRequestOperation_Private.h"
#import "SBService.h"

@interface SBGetEventListResultProcessor : SBResultProcessor

@end

@implementation SBGetEventListRequest

- (NSString *)method
{
    return @"getEventList";
}

- (SBResultProcessor *)resultProcessor
{
    return [[SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSDictionary class]]
            addResultProcessorToChain:[SBGetEventListResultProcessor new]];
}

@end

@implementation SBGetEventListResultProcessor

- (BOOL)process:(id)result
{
    self.result = [[SBServicesCollection alloc] initWithDictionary:result builder:[SBServiceEntryBuilder new]];
    return [super process:self.result];
}

@end