//
//  SBSessionManager.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 19.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBSessionManager.h"
#import "SBGetUserTokenRequest.h"
#import "SBGetServiceUrlRequest.h"
#import "SBGetCurrentUserDetailsRequest.h"
#import "SBUser.h"

#define SBSessionStorageKeyForCompanyLogin(companyLogin) ([NSString stringWithFormat:@"SBSessionStorageKey-%@", (companyLogin)])

NSString *const SBSessionManagerErrorDomain = @"SBSessionManagerErrorDomain";
NSString *const kSBSessionManagerDidEndSessionNotification = @"kSBSessionManagerDidEndSessionNotification";

NSString *const SBLoginServiceError_WrongCompanyResponseMessage = @"company does not exist";
NSString *const SBLoginServiceError_WrongAPIKey = @"wrong api key";
NSString *const SBLoginServiceError_InvalidCredentials = @"user with this login and password not found";
NSString *const SBLoginServiceError_UserIsBlocked = @"user is blocked";
NSString *const SBLoginServiceError_HIPAAGuard = @"you are not allowed to use this application when hipaa plugin is enabled";

@interface SBSessionManager ()

@property (nonatomic, strong) SBSession *defaultSession;
@property (nonatomic, strong) NSMutableArray *observers;
@property (nonatomic, strong) NSOperationQueue *authQueue;

@end

@implementation SBSessionManager

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    static id instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (NSMutableArray *)observers
{
    if (!_observers) {
        _observers = [[NSMutableArray alloc] init];
    }
    return _observers;
}

- (NSOperationQueue *)authQueue
{
    if (!_authQueue) {
        _authQueue = [[NSOperationQueue alloc] init];
    }
    return _authQueue;
}

- (void)startSessionWithCredentials:(SBSessionCredentials *)sessionCredentials
{
    SBGetServiceUrlRequest *serviceURLRequest = [[SBGetServiceUrlRequest alloc] initWithCompanyLogin:sessionCredentials.companyLogin];
    serviceURLRequest.callback = ^(SBResponse *response) {
        if (response.error) {
            NSError *error = nil;
            NSInteger errorCode = -1;
            if ([[response.error.userInfo[SBServerMessageKey] lowercaseString] isEqualToString:SBLoginServiceError_WrongCompanyResponseMessage]) {
                errorCode = SBWrongCompanyLoginErrorCode;
            } else if ([[response.error.userInfo[SBServerMessageKey] lowercaseString] isEqualToString:SBLoginServiceError_InvalidCredentials]) {
                errorCode = SBWrongCredentialsErrorCode;
            } else if ([[response.error.userInfo[SBServerMessageKey] lowercaseString] isEqualToString:SBLoginServiceError_UserIsBlocked]) {
                errorCode = SBUserBlockedErrorCode;
            } else if ([[response.error.userInfo[SBServerMessageKey] lowercaseString] isEqualToString:SBLoginServiceError_HIPAAGuard]) {
                errorCode = SBHIPAAErrorCode;
            }
            if (errorCode == -1) {
                error = response.error;
            } else {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: response.error.userInfo[SBServerMessageKey],
                                           NSUnderlyingErrorKey: response.error};
                error = [NSError errorWithDomain:SBSessionManagerErrorDomain
                                            code:errorCode userInfo:userInfo];
            }
        } else {
            NSString *domainString = response.result;
            SBGetUserTokenRequest *request = [[SBGetUserTokenRequest alloc] initWithComanyLogin:sessionCredentials.companyLogin];
            request.login = sessionCredentials.userLogin;
            request.password = sessionCredentials.password;
            request.callback = ^(SBResponse *response) {
                if (response.error) {
                    NSError *error = nil;
                    if (response.error && [[response.error.userInfo[SBServerMessageKey] lowercaseString] isEqualToString:SBLoginServiceError_InvalidCredentials]) {
                        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: response.error.userInfo[SBServerMessageKey],
                                                   NSUnderlyingErrorKey: response.error};
                        error = [NSError errorWithDomain:SBSessionManagerErrorDomain
                                                    code:SBWrongCredentialsErrorCode
                                                userInfo:userInfo];
                    } else if (response.error) {
                        error = response.error;
                    }
                    [self.observers enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> object, NSUInteger index, BOOL *stop) {
                        [object sessionManager:self didFailStartSessionWithError:error];
                    }];
                } else if ([response isEqual:[SBNullResponse nullResponse]]
                           || !response.result
                           || ([response.result isKindOfClass:[NSString class]] && [response.result isEqualToString:@""]))
                {
                    NSError *managerError = [NSError errorWithDomain:SBSessionManagerErrorDomain
                                                                code:SBNoTokenErrorCode
                                                            userInfo:@{NSLocalizedDescriptionKey: @"No auth token received from server."}];
                    [self.observers enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> object, NSUInteger index, BOOL *stop) {
                        [object sessionManager:self didFailStartSessionWithError:managerError];
                    }];
                } else {
                    NSString *token = response.result;
                    SBGetCurrentUserDetailsRequest *request = [[SBGetCurrentUserDetailsRequest alloc] initWithToken:token comanyLogin:sessionCredentials.companyLogin];
                    request.callback = ^(SBResponse *response) {
                        if (response.error) {
                            [self.observers enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> object, NSUInteger index, BOOL *stop) {
                                [object sessionManager:self didFailStartSessionWithError:response.error];
                            }];
                        } else {
                            SBUser *user = (SBUser *)response.result;
                            if ([user isBlocked]) {
                                NSError *error = [NSError errorWithDomain:SBSessionManagerErrorDomain code:SBUserBlockedErrorCode userInfo:@{}];
                                [self.observers enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> object, NSUInteger index, BOOL *stop) {
                                    [object sessionManager:self didFailStartSessionWithError:error];
                                }];
                            } else {
                                user.credentials = sessionCredentials;
                                SBSession *session = [[SBSession alloc] initWithUser:user token:token domain:domainString];
                                [self.observers enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> object, NSUInteger index, BOOL *stop) {
                                    [object sessionManager:self didStartSession:session];
                                }];
                            }
                        }
                    };
                    [self.authQueue addOperation:request];
                }
            };
            [self.authQueue addOperation:request];
        }
    };
    [self.authQueue addOperation:serviceURLRequest];
}

- (void)restoreSessionWithCredentials:(SBSessionCredentials *)sessionCredentials
{
    NSParameterAssert(sessionCredentials != nil);
    NSParameterAssert(![sessionCredentials.companyLogin isEqualToString:@""]);
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:SBSessionStorageKeyForCompanyLogin(sessionCredentials.companyLogin)];
    if (token) {
        SBGetCurrentUserDetailsRequest *request = [[SBGetCurrentUserDetailsRequest alloc] initWithToken:token comanyLogin:sessionCredentials.companyLogin];
        request.callback = ^(SBResponse *response) {
            if (response.error) {
                if (response.error.code == SBInvalidAuthTokenErrorCode) {
                    [self startSessionWithCredentials:sessionCredentials];
                    return;
                }
                [self.observers enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> object, NSUInteger index, BOOL *stop) {
                    if ([object respondsToSelector:@selector(sessionManager:didFailRestoreSessionWithError:)]) {
                        [object sessionManager:self didFailRestoreSessionWithError:response.error];
                    }
                }];
            } else {
                SBUser *user = (SBUser *)response.result;
                if ([user isBlocked]) {
                    NSError *error = [NSError errorWithDomain:SBSessionManagerErrorDomain code:SBUserBlockedErrorCode userInfo:@{}];
                    [self.observers enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> object, NSUInteger index, BOOL *stop) {
                        if ([object respondsToSelector:@selector(sessionManager:didFailRestoreSessionWithError:)]) {
                            [object sessionManager:self didFailRestoreSessionWithError:error];
                        }
                    }];
                } else {
                    user.credentials = sessionCredentials;
                    SBSession *session = [[SBSession alloc] initWithUser:user token:token domain:nil];
                    [self.observers enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> object, NSUInteger index, BOOL *stop) {
                        if ([object respondsToSelector:@selector(sessionManager:didRestoreSession:)]) {
                            [object sessionManager:self didRestoreSession:session];
                        }
                    }];
                }
            }
        };
        [self.authQueue addOperation:request];
    } else {
        [self.observers enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> object, NSUInteger index, BOOL *stop) {
            if ([object respondsToSelector:@selector(sessionManager:didFailRestoreSessionWithError:)]) {
                [object sessionManager:self didFailRestoreSessionWithError:nil];
            }
        }];
    }
}

- (void)startSessionWithUser:(SBUser *)user token:(NSString *)token domain:(NSString *)serverDomain
{
    SBSession *session = [[SBSession alloc] initWithUser:user token:token domain:serverDomain];
    [self.observers enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> object, NSUInteger index, BOOL *stop) {
        [object sessionManager:self didStartSession:session];
    }];
}

- (void)endSession:(SBSession *)session
{
    [self.observers enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> observer, NSUInteger index, BOOL *step) {
        [observer sessionManager:self willEndSession:session];
    }];
    NSString *companyLogin = session.user.credentials.companyLogin;
    NSString *userLogin = session.user.credentials.userLogin;
    [session invalidate];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:SBSessionStorageKeyForCompanyLogin(companyLogin)];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (session == self.defaultSession) {
        self.defaultSession = nil;
    }
    [self.observers enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> observer, NSUInteger index, BOOL *step) {
        [observer sessionManager:self didEndSessionForCompany:companyLogin user:userLogin];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSBSessionManagerDidEndSessionNotification
                                                        object:nil userInfo:@{@"company" : companyLogin ? companyLogin : @"(null)", @"user" : userLogin ? userLogin : @"(null)"}];
}

- (void)addObserver:(NSObject<SBSessionManagerDelegateObserver> *)observer
{
    if (!self.observers) {
        self.observers = [NSMutableArray array];
    }
    if (![self.observers containsObject:observer]) {
        [self.observers addObject:observer];
    }
}

- (void)removeObserver:(NSObject<SBSessionManagerDelegateObserver> *)observer
{
    [self.observers removeObject:observer];
}

@end
