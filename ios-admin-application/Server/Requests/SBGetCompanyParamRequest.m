//
//  SBGetCompanyParamRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 14.12.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBGetCompanyParamRequest.h"
#import "SBRequestOperation_Private.h"

@interface SBGetCompanyParamResultProcessor : SBResultProcessor

@end

@implementation SBGetCompanyParamRequest

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.paramKey = self.paramKey;
    return copy;
}

- (NSString *)method
{
    return @"getCompanyParam";
}

- (NSArray *)params
{
    NSAssert(self.paramKey != nil, @"no param key specified");
    NSAssert(![self.paramKey isEqualToString:@""], @"no param key specified");
    return @[self.paramKey];
}

- (SBResultProcessor *)resultProcessor
{
    return [SBGetCompanyParamResultProcessor new];
}

@end

@implementation SBGetCompanyParamResultProcessor

- (BOOL)process:(id)result
{
    if ([result isKindOfClass:[NSString class]]) {
        self.result = result;
    }
    else if ([result respondsToSelector:@selector(stringValue)]) {
        self.result = [result stringValue];
    }
    else {
        self.result = [NSString stringWithFormat:@"%@", result];
    }
    return [self chainResult:self.result success:YES];
}

@end