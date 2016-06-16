//
//  SBGetServiceUrlRequest.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 20.04.16.
//  Copyright © 2016 Michail Grebionkin. All rights reserved.
//

#import "SBRequestOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface SBGetServiceUrlRequest : SBLoginRequest

- (instancetype)initWithCompanyLogin:(NSString *)companyLogin;

@end

NS_ASSUME_NONNULL_END