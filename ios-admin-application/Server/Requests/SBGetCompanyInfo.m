//
//  SBGetCompanyInfo.m
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 14.07.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import "SBGetCompanyInfo.h"
#import "SBRequestOperation_Private.h"
#import "SBCompanyInfo.h"
#import "SBResultProcessor.h"

@interface SBGetCompanyResultProcessor : SBResultProcessor

@end

@implementation SBGetCompanyInfo

- (NSString *)method
{
    return @"getCompanyInfo";
}

- (NSArray *)params
{
    return @[];
}

- (SBResultProcessor *)resultProcessor
{
    return [[SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSDictionary class]]
            addResultProcessorToChain:[SBGetCompanyResultProcessor new]];
}

@end

@implementation SBGetCompanyResultProcessor

- (BOOL)process:(id)result
{
    self.result = [[SBCompanyInfo alloc] initWithDict:result];
    return YES;
}

@end