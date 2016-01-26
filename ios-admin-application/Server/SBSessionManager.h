//
//  SBSessionManager.h
//  ios-admin-application
//
//  Created by Michail Grebionkin on 19.08.15.
//  Copyright (c) 2015 Michail Grebionkin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBSessionCredentials.h"
#import "SBSession.h"

extern NSString *const SBSessionManagerErrorDomain;
extern NSString *const kSBSessionManagerDidEndSessionNotification;

typedef NS_ENUM(NSInteger, SBSessionManagerErrorCodes)
{
    SBNoTokenErrorCode,
    SBWrongCredentialsErrorCode
};

@class SBSessionManager;

@protocol SBSessionManagerDelegateObserver <NSObject>

- (void)sessionManager:(SBSessionManager *)manager didStartSession:(SBSession *)session;
- (void)sessionManager:(SBSessionManager *)manager didFailStartSessionWithError:(NSError *)error;
- (void)sessionManager:(SBSessionManager *)manager willEndSession:(SBSession *)session;
- (void)sessionManager:(SBSessionManager *)manager didEndSessionForCompany:(NSString *)companyLogin user:(NSString *)userLogin;

@end

@interface SBSessionManager : NSObject

+ (instancetype)sharedManager;

- (SBSession *)defaultSession;
- (void)setDefaultSession:(SBSession *)session;
- (void)startSessionWithCredentials:(SBSessionCredentials *)sessionCredentials;
- (void)endSession:(SBSession *)session;
- (void)addObserver:(NSObject<SBSessionManagerDelegateObserver> *)observer;
- (void)removeObserver:(NSObject<SBSessionManagerDelegateObserver> *)observer;

@end
