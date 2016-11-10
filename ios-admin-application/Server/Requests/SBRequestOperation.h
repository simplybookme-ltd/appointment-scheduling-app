//
//  SBRequest.h
//  SimplyBookMobile 
//
//  Created by Michail Grebionkin on 06.07.15.
//  Copyright (c) 2015 Capitan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBResponse.h"
#import "SBRequest.h"
#import "SBCache.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SBRequestErrorCodes) {
    SBUnknownErrorCode,
    SBEmptyResponseErrorCode,
    SBEmptyResponseBodyErrorCode,
    SBUnexpectedServerResponseErrorCode,
    SBInvalidAuthTokenErrorCode,
    SBServerErrorCode,
    SBUserCancelledErrorCode
};

typedef NS_ENUM(NSInteger, SBServerErrorCodes) {
    SB_SERVER_ERROR_PLUGIN_DISABLED = -32001,
    SB_SERVER_ERROR_EVENT_ID_VALUE = -32051,
    SB_SERVER_ERROR_UNIT_ID_VALUE = -32052,
    SB_SERVER_ERROR_DATE_VALUE = -32053,
    SB_SERVER_ERROR_TIME_VALUE = -32054,
    SB_SERVER_ERROR_RECURRENT_BOOKING = -32055,
    SB_SERVER_ERROR_CLIENT_NAME_VALUE = -32061,
    SB_SERVER_ERROR_CLIENT_EMAIL_VALUE = -32062,
    SB_SERVER_ERROR_CLIENT_PHONE_VALUE = -32063,
    SB_SERVER_ERROR_CLIENT_ID = -3264,
    SB_SERVER_ERROR_ADDITIONAL_FIELDS = -32070,
    SB_SERVER_ERROR_APPOINTMENT_NOT_FOUND = -32080,
    SB_SERVER_ERROR_SIGN = -32085,
    SB_SERVER_ERROR_APPLICATION_CONFIRMATION = -32090,
    SB_SERVER_ERROR_BATCH_NOT_FOUND = -32095,
    SB_SERVER_ERROR_UNSUPPORTED_PAYMENT_SYSTEM = -32097,
    SB_SERVER_ERROR_PAYMENT_FAILED = -32099,
    SB_SERVER_ERROR_REQUIRED_PARAMS_MISSED = -32010,
    SB_SERVER_ERROR_PARAMS_IS_NOT_ARRAY = -32011
};

@class SBRequestOperation;
@protocol SBRequestDelegate;
@protocol SBRequestProtocol;

typedef void (^SBRequestCallback)(SBResponse <id> *response);
typedef void (^SBRequestPredispatchBlock)(SBRequest *request);

extern NSString *const SBRequestErrorDomain;
extern NSString *const SBServerErrorDomain;
extern NSString *const SBServerMessageKey;


@protocol SBRequestProtocol <NSObject>

@property (nonatomic, readonly) NSString *GUID;
@property (nonatomic, weak, nullable) NSObject<SBRequestDelegate> *delegate;
@property (nonatomic, copy, nullable) SBRequestCallback callback;
@property (nonatomic, copy, nullable) SBRequestPredispatchBlock predispatchBlock;
@property (nonatomic) SBCachePolicy cachePolicy;

- (nullable instancetype)copyWithToken:(nullable NSString *)token;

@end


@protocol SBRequestDelegate <NSObject>

- (BOOL)request:(SBRequest *)request didFinishWithResponse:(SBResponse <id> *)response;

@optional
- (BOOL)shouldDispatchRequest:(SBRequest *)request;

@end


@interface SBRequestOperation : NSBlockOperation <SBRequestProtocol>

@property (nonatomic, readonly) NSString *endPointString;
@property (nonatomic, readonly) NSURL *endPointURL;
@property (nonatomic, readonly) NSDictionary *headers;
@property (nonatomic, readonly) NSUInteger requestID;
@property (nonatomic, readonly) NSString *method;
@property (nonatomic, readonly, copy) NSString *companyLogin;
@property (nonatomic, copy, nullable) SBRequestPredispatchBlock predispatchBlock;

+ (void)setDomainString:(NSString *)domainString;

- (nullable instancetype)initWithToken:(nullable NSString *)token comanyLogin:(nullable NSString *)companyLogin;
- (nullable instancetype)copyWithToken:(nullable NSString *)token;
- (NSData *)cacheKey;

@end

@interface SBLoginRequest : SBRequestOperation

@end

NS_ASSUME_NONNULL_END
