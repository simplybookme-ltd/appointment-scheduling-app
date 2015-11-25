//
//  SBSetStatusRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 16.11.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

/// @see http://wiki.simplybook.me/index.php/Plugins#Status
@interface SBSetStatusRequest : SBRequestOperation

@property (nonatomic, copy, nonnull) NSString *bookingID;
@property (nonatomic, copy, nonnull) NSString *statusID;

@end
