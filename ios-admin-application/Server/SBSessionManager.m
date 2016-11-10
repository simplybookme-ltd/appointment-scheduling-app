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
#import "SBRequestsGroup.h"
#import "SBIsPluginActivatedRequest.h"
#import "SBPluginsRepository.h"

#define SBSessionStorageKeyForCompanyLogin(companyLogin) ([NSString stringWithFormat:@"SBSessionStorageKey-%@", (companyLogin)])

NSString *const SBSessionManagerErrorDomain = @"SBSessionManagerErrorDomain";
NSString *const kSBSessionManagerDidEndSessionNotification = @"kSBSessionManagerDidEndSessionNotification";
NSString *const kSBSessionManagerCompanyLoginKey = @"kSBSessionManagerCompanyLoginKey";

NSString *const SBLoginServiceError_WrongCompanyResponseMessage = @"company does not exist";
NSString *const SBLoginServiceError_WrongAPIKey = @"wrong api key";
NSString *const SBLoginServiceError_InvalidCredentials = @"user with this login and password not found";
NSString *const SBLoginServiceError_UserIsBlocked = @"user is blocked";
NSString *const SBLoginServiceError_HIPAAGuard = @"you are not allowed to use this application when hipaa plugin is enabled";

@interface SBSessionManager () <SBRequestDelegate>

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
                [self enumerateObserversUsingBlock:^(id<SBSessionManagerDelegateObserver> observer, NSUInteger index, BOOL *step) {
                    [observer sessionManager:self didFailStartSessionWithError:error];
                }];
            }
        } else {
            NSString *domainString = response.result;
            [SBSession setDomainString:domainString companyLogin:sessionCredentials.companyLogin];
            
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
                    [self enumerateObserversUsingBlock:^(id<SBSessionManagerDelegateObserver> observer, NSUInteger index, BOOL *step) {
                        [observer sessionManager:self didFailStartSessionWithError:error];
                    }];
                } else if ([response isEqual:[SBNullResponse nullResponse]]
                           || !response.result
                           || ([response.result isKindOfClass:[NSString class]] && [response.result isEqualToString:@""]))
                {
                    NSError *managerError = [NSError errorWithDomain:SBSessionManagerErrorDomain
                                                                code:SBNoTokenErrorCode
                                                            userInfo:@{NSLocalizedDescriptionKey: @"No auth token received from server."}];
                    [self enumerateObserversUsingBlock:^(id<SBSessionManagerDelegateObserver> observer, NSUInteger index, BOOL *step) {
                        [observer sessionManager:self didFailStartSessionWithError:managerError];
                    }];
                } else {
                    NSString *token = response.result;
                    [self validateSessionWithToken:token sessionCredentials:sessionCredentials callback:^(SBUser *user, NSError *error) {
                        if (error) {
                            [self enumerateObserversUsingBlock:^(id<SBSessionManagerDelegateObserver> observer, NSUInteger index, BOOL *step) {
                                [observer sessionManager:self didFailStartSessionWithError:error];
                            }];
                        } else {
                            user.credentials = sessionCredentials;
                            SBSession *session = [[SBSession alloc] initWithUser:user token:token];
                            [self enumerateObserversUsingBlock:^(id<SBSessionManagerDelegateObserver> observer, NSUInteger index, BOOL *step) {
                                [observer sessionManager:self didStartSession:session];
                            }];
                        }
                    }];
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
        [self validateSessionWithToken:token sessionCredentials:sessionCredentials callback:^(SBUser *user, NSError *error) {
            if (error.code == SBInvalidAuthTokenErrorCode) {
                [self startSessionWithCredentials:sessionCredentials];
                return;
            }
            user.credentials = sessionCredentials;
            SBSession *session = [[SBSession alloc] initWithUser:user token:token];
            [self enumerateObserversUsingBlock:^(id<SBSessionManagerDelegateObserver> observer, NSUInteger index, BOOL *step) {
                if ([observer respondsToSelector:@selector(sessionManager:didRestoreSession:)]) {
                    [observer sessionManager:self didRestoreSession:session];
                }
            }];
        }];
    } else {
        [self enumerateObserversUsingBlock:^(id<SBSessionManagerDelegateObserver> observer, NSUInteger index, BOOL *step) {
            if ([observer respondsToSelector:@selector(sessionManager:didFailRestoreSessionWithError:)]) {
                [observer sessionManager:self didFailRestoreSessionWithError:nil];
            }
        }];
    }
}

- (void)startSessionWithUser:(SBUser *)user token:(NSString *)token domain:(NSString *)serverDomain
{
    [SBSession setDomainString:serverDomain companyLogin:user.credentials.companyLogin];
    SBSession *session = [[SBSession alloc] initWithUser:user token:token];
    [self enumerateObserversUsingBlock:^(id<SBSessionManagerDelegateObserver> observer, NSUInteger index, BOOL *step) {
        [observer sessionManager:self didStartSession:session];
    }];
}

- (void)endSession:(SBSession *)session
{
    [self enumerateObserversUsingBlock:^(id<SBSessionManagerDelegateObserver> observer, NSUInteger index, BOOL *step) {
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
    [self enumerateObserversUsingBlock:^(id<SBSessionManagerDelegateObserver> observer, NSUInteger index, BOOL *step) {
        [observer sessionManager:self didEndSessionForCompany:companyLogin user:userLogin];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSBSessionManagerDidEndSessionNotification
                                                        object:nil userInfo:@{@"company" : companyLogin ? companyLogin : @"(null)", @"user" : userLogin ? userLogin : @"(null)"}];
}

- (void)validateSessionWithToken:(NSString *)token sessionCredentials:(SBSessionCredentials *)sessionCredentials callback:(void (^)(SBUser *user, NSError *error))callback
{
    NSParameterAssert(token != nil && ![token isEqualToString:@""]);
    NSParameterAssert(sessionCredentials != nil && sessionCredentials.companyLogin != nil && ![sessionCredentials.companyLogin isEqualToString:@""]);
    SBRequestsGroup *group = [[SBRequestsGroup alloc] init];
    
    __block SBUser *user;
    SBGetCurrentUserDetailsRequest *getUserDetailsRequest = [[SBGetCurrentUserDetailsRequest alloc] initWithToken:token comanyLogin:sessionCredentials.companyLogin];
    getUserDetailsRequest.callback = ^(SBResponse *response) {
        user = (SBUser *)response.result;
    };
    getUserDetailsRequest.cachePolicy = SBIgnoreCachePolicy;
    [group addRequest:getUserDetailsRequest];
    
    __block BOOL pluginActivated = NO;
    SBIsPluginActivatedRequest *pluginStatusRequest = [[SBIsPluginActivatedRequest alloc] initWithToken:token comanyLogin:sessionCredentials.companyLogin];
    pluginStatusRequest.pluginName = kSBPluginRepositoryMobileApplicationPlugin;
    pluginStatusRequest.callback = ^(SBResponse *response) {
        pluginActivated = (response.result && [response.result respondsToSelector:@selector(boolValue)] ? [response.result boolValue] : NO);
    };
    pluginStatusRequest.cachePolicy = SBIgnoreCachePolicy;
    [group addRequest:pluginStatusRequest];
    
    group.callback = ^(SBResponse *response) {
        if (response.error) {
            callback(nil, response.error);
        } else {
            if ([user isBlocked]) {
                NSError *error = [NSError errorWithDomain:SBSessionManagerErrorDomain code:SBUserBlockedErrorCode
                                                 userInfo:@{kSBSessionManagerCompanyLoginKey: sessionCredentials.companyLogin}];
                callback(nil, error);
            } else if (pluginActivated == NO) {
                NSError *error = [NSError errorWithDomain:SBSessionManagerErrorDomain code:SBMobileAppPluginErrorCode
                                                 userInfo:@{kSBSessionManagerCompanyLoginKey: sessionCredentials.companyLogin}];
                callback(nil, error);
            } else {
                callback(user, nil);
            }
        }
    };
    group.delegate = self;
    [self.authQueue addOperation:group];
    [self.authQueue addOperations:group.dependencies waitUntilFinished:NO];
}

- (BOOL)request:(SBRequest *)request didFinishWithResponse:(SBResponse *)response
{
    return YES;
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

/// enumerate immutable copy to prevent adding/removing observers during enumeration
- (void)enumerateObserversUsingBlock:(void (^)(id<SBSessionManagerDelegateObserver> observer, NSUInteger index, BOOL *step))block
{
    NSArray *safeCopy = [[NSArray alloc] initWithArray:self.observers];
    [safeCopy enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> observer, NSUInteger idx, BOOL * _Nonnull stop) {
        block(observer, idx, stop);
    }];
}

@end
