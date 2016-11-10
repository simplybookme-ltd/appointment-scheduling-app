//
//  SBGetBookingCommentRequest.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 01.08.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "SBGetBookingCommentRequest.h"
#import "SBRequestOperation_Private.h"

@implementation SBGetBookingCommentRequest

- (NSString *)method
{
    return @"getBookingComment";
}

- (NSArray *)params
{
    NSParameterAssert(self.bookingID != nil);
    return @[self.bookingID ? self.bookingID : @"0"];
}

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.bookingID = self.bookingID;
    return copy;
}

- (SBResultProcessor *)resultProcessor
{
    return [SBClassCheckProcessor classCheckProcessorWithExpectedClass:[NSString class]];
}

@end
