//
//  SBPluginApproveBookingApproveRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 16.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

/**
 * Warning: SBPluginApproveBookingApproveRequest always has SBNoCachePolicy.
 *
 * @see http://wiki.simplybook.me/index.php/Plugins#Approve_booking
 */
@interface SBPluginApproveBookingApproveRequest : SBRequestOperation

@property (nonatomic, copy, nonnull) NSString *bookingID;

@end
