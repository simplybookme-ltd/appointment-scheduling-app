//
//  SBBookRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 02.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"
#import "SBBookingForm.h"

@interface SBBookRequest : SBRequestOperation

@property (nonatomic, strong) SBBookingForm *formData;

@end
