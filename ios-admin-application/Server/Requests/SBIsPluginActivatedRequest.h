//
//  SBIsPluginActivatedRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 13.10.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

@interface SBIsPluginActivatedRequest : SBRequestOperation

@property (nonatomic, copy) NSString *pluginName;

@end
