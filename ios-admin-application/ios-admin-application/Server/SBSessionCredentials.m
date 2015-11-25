//
//  SBSessionCredentials.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 19.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBSessionCredentials.h"

static NSString *const kSBCredentialsCompanyLoginKeychainKey = @"kSBCredentialsCompanyLoginKeychainKey";
static NSString *const kSBCredentialsUserLoginKeychainKey = @"kSBCredentialsUserLoginKeychainKey";
static NSString *const kSBCredentialsPasswordKeychainKey = @"kSBCredentialsPasswordKeychainKey";

@interface SBSessionCredentials ()

@property (nonatomic, readwrite) NSString *companyLogin;
@property (nonatomic, readwrite) NSString *userLogin;
@property (nonatomic, readwrite) NSString *password;

@end

@implementation SBSessionCredentials

+ (instancetype)credentialsForCompanyLogin:(NSString *)companyLogin userLogin:(NSString *)userLogin password:(NSString *)password
{
    return [[self alloc] initWithCompanyLogin:companyLogin userLogin:userLogin password:password];
}

+ (nullable instancetype)credentialsFromKeychain:(nonnull FXKeychain *)keychain
{
    if (![keychain objectForKey:kSBCredentialsCompanyLoginKeychainKey]
        || ![keychain objectForKey:kSBCredentialsUserLoginKeychainKey]
        || ![keychain objectForKey:kSBCredentialsPasswordKeychainKey]) {
        return nil;
    }
    return [[self alloc] initWithCompanyLogin:[keychain objectForKey:kSBCredentialsCompanyLoginKeychainKey]
                                    userLogin:[keychain objectForKey:kSBCredentialsUserLoginKeychainKey]
                                     password:[keychain objectForKey:kSBCredentialsPasswordKeychainKey]];
}

- (instancetype)initWithCompanyLogin:(NSString *)companyLogin userLogin:(NSString *)userLogin password:(NSString *)password
{
    self = [super init];
    if (self) {
        self.companyLogin = companyLogin;
        self.userLogin = userLogin;
        self.password = password;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    typeof (self) copy = [[self class] allocWithZone:zone];
    copy.companyLogin = self.companyLogin;
    copy.userLogin = self.userLogin;
    copy.password = self.password;
    return copy;
}

- (NSString *)description
{
    return [@{@"companyLogin": self.companyLogin, @"userLogin": self.userLogin, @"password": (self.password ? @"***" : [NSNull null])} description];
}

- (void)saveToKeychain:(FXKeychain *)keychain
{
    [keychain setObject:self.companyLogin forKey:kSBCredentialsCompanyLoginKeychainKey];
    [keychain setObject:self.userLogin forKey:kSBCredentialsUserLoginKeychainKey];
    [keychain setObject:self.password forKey:kSBCredentialsPasswordKeychainKey];
}

- (void)removeFromKeychain:(FXKeychain *)keychain
{
    [keychain setObject:nil forKey:kSBCredentialsCompanyLoginKeychainKey];
    [keychain setObject:nil forKey:kSBCredentialsUserLoginKeychainKey];
    [keychain setObject:nil forKey:kSBCredentialsPasswordKeychainKey];
}

@end
