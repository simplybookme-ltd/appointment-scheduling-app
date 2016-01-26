//
//  SBSetStatusRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 16.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBSetStatusRequest.h"
#import "SBRequestOperation_Private.h"

@implementation SBSetStatusRequest

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.bookingID = self.bookingID;
    copy.statusID = self.statusID;
    return copy;
}

- (NSString *)method
{
    return @"setStatus";
}

- (NSArray *)params
{
    NSAssert(self.bookingID != nil, @"required parametr bookingID can't be nil");
    NSAssert(self.statusID != nil, @"required parametr statusID can't be nil");
    return @[self.bookingID, self.statusID];
}

- (SBResultProcessor *)resultProcessor
{
    return [[SBDebugProcessor debugProcessor] addResultProcessorToChain:[SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSNumber class]]];
}

@end
