//
//  SBSessionCredentials.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 19.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FXKeychain.h"

@interface SBSessionCredentials : NSObject <NSCopying>

@property (nonatomic, readonly, copy) NSString *companyLogin;
@property (nonatomic, readonly, copy) NSString *userLogin;
@property (nonatomic, readonly, copy) NSString *password;
                              
+ (instancetype)credentialsForCompanyLogin:(NSString *)companyLogin userLogin:(NSString *)userLogin password:(NSString *)password;
+ (instancetype)credentialsFromKeychain:(FXKeychain *)keychain;

- (void)saveToKeychain:(FXKeychain *)keychain;
- (void)removeFromKeychain:(FXKeychain *)keychain;

@end
