//
//  SBGetUserTokenRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 18.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

@interface SBGetUserTokenRequest : SBLoginRequest

@property (nonatomic, copy) NSString *login;
@property (nonatomic, copy) NSString *password;

- (instancetype)initWithComanyLogin:(NSString *)companyLogin;

@end
