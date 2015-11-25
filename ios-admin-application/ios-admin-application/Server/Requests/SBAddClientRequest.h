//
//  SBAddClientRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 02.09.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

@interface SBAddClientRequest : SBRequestOperation

@property (nonatomic, copy) NSString *clientName;
@property (nonatomic, copy) NSString *phone;
@property (nonatomic, copy) NSString *email;

@end
