//
//  SBNewBookingPlaceholder.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 16.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBNewBookingPlaceholder.h"

@implementation SBNewBookingPlaceholder

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isConfirmed = @(YES);
        self.bookingID = @"0";
    }
    return self;
}

@end
