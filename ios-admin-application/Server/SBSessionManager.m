//
//  SBSessionManager.m
//  ios-admin-application
//
//  Created by Michail Grebionkin on 19.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import "SBSessionManager.h"
#import "SBGetUserTokenRequest.h"

NSString *const SBSessionManagerErrorDomain = @"SBSessionManagerErrorDomain";
NSString *const kSBSessionManagerDidEndSessionNotification = @"kSBSessionManagerDidEndSessionNotification";

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
    SBGetUserTokenRequest *request = [[SBGetUserTokenRequest alloc] initWithComanyLogin:sessionCredentials.companyLogin];
    request.login = sessionCredentials.userLogin;
    request.password = sessionCredentials.password;
    request.callback = ^(SBResponse *response) {
        if (response.error) {
            NSError *error = nil;
            if (response.error && [[response.error.userInfo[SBServerMessageKey] lowercaseString] isEqualToString:@"user with this login and password not found"]) {
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
            SBSession *session = [[SBSession alloc] initWithCompanyLogin:sessionCredentials.companyLogin token:response.result];
            [session assignSessionCredentials:sessionCredentials];
            [self.observers enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> object, NSUInteger index, BOOL *stop) {
                [object sessionManager:self didStartSession:session];
            }];
        }
    };
    [self.authQueue addOperation:request];
}

- (void)endSession:(SBSession *)session
{
    [self.observers enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> observer, NSUInteger index, BOOL *step) {
        [observer sessionManager:self willEndSession:session];
    }];
    NSString *companyLogin = session.companyLogin;
    NSString *userLogin = session.userLogin;
    [session invalidate];
    if (session == self.defaultSession) {
        self.defaultSession = nil;
    }
    [self.observers enumerateObjectsUsingBlock:^(id<SBSessionManagerDelegateObserver> observer, NSUInteger index, BOOL *step) {
        [observer sessionManager:self didEndSessionForCompany:companyLogin user:userLogin];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSBSessionManagerDidEndSessionNotification
                                                        object:nil userInfo:@{@"company" : companyLogin, @"user" : userLogin}];
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
