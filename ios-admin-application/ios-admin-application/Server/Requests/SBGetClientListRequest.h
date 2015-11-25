//
//  SBGetClientListRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 01.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

@interface SBGetClientListRequest : SBRequestOperation

@property (nonatomic, copy) NSString *pattern;

@end
