//
//  SBEditBookRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 08.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"
#import "SBBookingForm.h"

@interface SBEditBookRequest : SBRequestOperation

@property (nonatomic, strong) SBBookingForm *formData;

@end
