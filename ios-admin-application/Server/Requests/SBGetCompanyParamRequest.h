//
//  SBGetCompanyParamRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 14.12.15.
//  Copyright © 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

@interface SBGetCompanyParamRequest : SBRequestOperation

@property (nonatomic, copy) NSString *paramKey;

@end
