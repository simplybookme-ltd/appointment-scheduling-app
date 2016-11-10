//
//  SBSetBookingComment.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 01.08.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

@interface SBSetBookingCommentRequest : SBRequestOperation

@property (nonatomic, copy, nullable) NSString *bookingID;
@property (nonatomic, copy, nullable) NSString *comment;

@end
