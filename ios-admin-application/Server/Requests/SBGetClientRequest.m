//
//  SBGetClientRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 04.03.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "SBGetClientRequest.h"
#import "SBRequestOperation_Private.h"

@implementation SBGetClientRequest

- (NSString *)method
{
    return @"getClient";
}

- (NSArray *)params
{
    NSAssert(self.clientID != nil && ![self.clientID isEqualToString:@""], @"Invalid client id");
    return @[self.clientID];
}

- (instancetype)copyWithToken:(NSString *)token
{
    typeof(self) copy = [super copyWithToken:token];
    copy.clientID = self.clientID;
    return copy;
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSDictionary class]];
}

@end
