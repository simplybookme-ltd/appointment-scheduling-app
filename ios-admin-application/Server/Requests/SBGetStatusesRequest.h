//
//  SBGetStatuses.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.09.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

/**
 * Loads list of booking statuses if plugin 'Status' enabled.
 * @see http://wiki.simplybook.me/index.php/Plugins#Status
 */
@interface SBGetStatusesRequest : SBRequestOperation

@end
