//
//  SBSetBookingComment.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 01.08.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "SBSetBookingCommentRequest.h"
#import "SBRequestOperation_Private.h"

@implementation SBSetBookingCommentRequest

- (NSString *)method
{
    return @"setBookingComment";
}

- (NSArray *)params
{
    NSParameterAssert(self.bookingID != nil);
    NSParameterAssert(self.comment != nil);
    return @[self.bookingID ? self.bookingID : @"0", self.comment ? self.comment : @""];
}

- (instancetype)copyWithToken:(NSString *)token
{
    typeof (self) copy = [super copyWithToken:token];
    copy.bookingID = self.bookingID;
    copy.comment = self.comment;
    return copy;
}

- (SBResultProcessor *)resultProcessor
{
    return [SBDebugProcessor debugProcessor];
}

@end
