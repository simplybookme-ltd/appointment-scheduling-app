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

- (void)initializeWithToken:(NSString *)token comanyLogin:(NSString *)companyLogin endpoint:(NSString *)endpoint
{
    [super initializeWithToken:token comanyLogin:companyLogin endpoint:endpoint];
    self.visibleOnly = NO;
    self.asArray = YES;
}

- (NSString *)method
{
    return @"getUnitList";
}

- (NSArray *)params
{
    return @[@(self.visibleOnly), @(self.asArray)];
}

- (SBResultProcessor *)resultProcessor
{
    return [[SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSArray class]]
            addResultProcessorToChain:[SBGetUnitListResultProcessor new]];
}

@end

@implementation SBGetUnitListResultProcessor

- (BOOL)process:(id)result
{
    self.result = [[SBPerformersCollection alloc] initWithArray:result builder:[SBPerformerEntryBuilder new]];
    return [super process:self.result];
}

@end
