//
//  SBGetAdditionalFieldsRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 02.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetAdditionalFieldsRequest.h"
#import "SBRequestOperation_Private.h"
#import "SBAdditionalField.h"

@interface SBGetAdditionalFieldsResultProcessor : SBResultProcessor

@end

@implementation SBGetAdditionalFieldsRequest

- (NSString *)method
{
    return @"getAdditionalFields";
}

- (NSArray *)params
{
    return @[self.eventID];
}

- (SBResultProcessor *)resultProcessor
{
    return [[SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSArray class]]
            addResultProcessorToChain:[SBGetAdditionalFieldsResultProcessor new]];
}

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.eventID = self.eventID;
    return copy;
}

@end

@implementation SBGetAdditionalFieldsResultProcessor

- (BOOL)process:(id)result
{
    NSMutableArray *list = [NSMutableArray array];
    for (NSDictionary *dict in result) {
        [list addObject:[[SBAdditionalField alloc] initWithDict:dict]];
    }
    self.result = [list sortedArrayUsingComparator:^NSComparisonResult(SBAdditionalField *obj1, SBAdditionalField *obj2) {
        return (obj1.position < obj2.position) ? NSOrderedAscending : (obj1.position > obj2.position ? NSOrderedDescending : NSOrderedSame);
    }];
    return [super process:self.result];
}

@end